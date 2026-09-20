import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../app/lume_app.dart';
import '../../../app/models.dart';
import '../../../app/ui.dart' as app_ui;
import '../../../core/photos/local_photo_service.dart';
import '../../../core/theme/lume_theme.dart';
import '../../../core/widgets/lume_widgets.dart';

Future<void> showGratitudeEditor(BuildContext context, {DateTime? date}) {
  final day = date ?? DateTime.now();
  final controller = AppScope.read(context);
  final today =
      controller.localDateFor(day) == controller.localDateFor(DateTime.now());
  return app_ui.showLumeSheet(
    context,
    title: today
        ? 'Gratidão de hoje'
        : 'Gratidão de ${controller.formatDate(day)}',
    child: GratitudeEditor(date: day),
  );
}

class GratitudeEditor extends StatefulWidget {
  const GratitudeEditor({required this.date, super.key});
  final DateTime date;

  @override
  State<GratitudeEditor> createState() => _GratitudeEditorState();
}

class _GratitudeEditorState extends State<GratitudeEditor> {
  final _text = TextEditingController();
  late final AppController _controller;
  late final String _owner;
  late final String _draftKey;
  GratitudeEntry? _original;
  String? _image;
  String? _message;
  String? _error;
  bool _initialized = false;
  bool _loading = true;
  bool _busy = false;
  bool _hasDraft = false;
  int _revision = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _controller = AppScope.read(context);
    _owner = _controller.draftOwner;
    _draftKey = 'gratitude:${_controller.localDateFor(widget.date)}';
    _original = _controller.gratitudeFor(widget.date).firstOrNull;
    _text.text = _original?.text ?? '';
    _image = _original?.localImagePath;
    unawaited(_restore());
  }

  Future<void> _restore() async {
    try {
      final draft = await _controller.readDraft(_draftKey);
      if (!mounted || _owner != _controller.draftOwner) return;
      if (draft != null && draft['text'] is String) {
        _text.text = draft['text'] as String;
        _image = draft['image'] is String ? draft['image'] as String : null;
        _hasDraft = true;
        _message = 'Rascunho recuperado. Continue de onde parou.';
      }
    } catch (_) {
      if (mounted) {
        _error = 'Não conseguimos recuperar o rascunho. Tente abrir novamente.';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _persist() async {
    final revision = ++_revision;
    setState(() {
      _message = 'Guardando rascunho…';
      _error = null;
      _hasDraft = true;
    });
    try {
      await _controller.writeDraft(_draftKey, {
        'text': _text.text,
        'image': _image,
      }, owner: _owner);
      if (mounted && revision == _revision) {
        setState(() => _message = 'Rascunho salvo neste aparelho');
      }
      return true;
    } catch (_) {
      if (mounted && revision == _revision) {
        setState(() {
          _message = null;
          _error =
              'Não foi possível guardar o rascunho. Mantenha esta tela aberta e tente novamente.';
        });
      }
      return false;
    }
  }

  Future<void> _pickPhoto() async {
    setState(() => _busy = true);
    try {
      final path = await _controller.pickLocalPhoto(LocalPhotoKind.gratitude);
      if (!mounted || path == null) return;
      setState(() => _image = path);
      await _persist();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Não foi possível abrir a foto. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_text.text.trim().isEmpty && _image == null) {
      setState(() => _error = 'Escreva algo ou adicione uma foto.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_owner != _controller.draftOwner || !_controller.signedIn) {
        throw StateError('Session changed');
      }
      await _persist();
      await _controller.saveGratitude(
        _text.text,
        date: widget.date,
        localImagePath: _image,
      );
      // The entry is already durable; a draft cleanup error must not undo it.
      try {
        await _controller.writeDraft(_draftKey, null, owner: _owner);
      } catch (_) {
        // A recovered copy remains editable and saving is idempotent by date.
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Não foi possível salvar. Seu texto continua aqui para tentar novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _discard() async {
    final confirmed = await _confirm(
      'Descartar este rascunho?',
      'As alterações não salvas serão removidas. A gratidão já guardada será mantida.',
      'Descartar',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await _controller.writeDraft(_draftKey, null, owner: _owner);
      if (!mounted) return;
      setState(() {
        _text.text = _original?.text ?? '';
        _image = _original?.localImagePath;
        _message = null;
        _error = null;
        _hasDraft = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível descartar. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await _confirm(
      'Excluir esta gratidão?',
      'O texto e a foto associados a este dia serão removidos do app.',
      'Excluir',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await _controller.writeDraft(_draftKey, null, owner: _owner);
      await _controller.removeGratitude(_controller.localDateFor(widget.date));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível excluir. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(
    String title,
    String description,
    String action,
  ) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return PopScope(
      canPop: !_busy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: GestureDetector(
                onTap: () => showLumePhotoViewer(
                  context,
                  path: _image!,
                  semanticLabel: 'Foto de gratidão',
                ),
                child: Image.file(
                  File(_image!),
                  height: 180,
                  fit: BoxFit.cover,
                  semanticLabel: 'Foto de gratidão',
                  errorBuilder: (_, error, stack) => const SizedBox(
                    height: 96,
                    child: Center(
                      child: Text(
                        'Foto indisponível. Você pode escolher outra.',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _busy
                    ? null
                    : () {
                        setState(() => _image = null);
                        unawaited(_persist());
                      },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remover foto'),
              ),
            ),
          ],
          TextField(
            key: const ValueKey('gratitude-text'),
            controller: _text,
            enabled: !_busy,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'O que foi bom hoje?',
              alignLabelWithHint: true,
            ),
            onChanged: (_) => unawaited(_persist()),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickPhoto,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_image == null ? 'Adicionar foto' : 'Trocar foto'),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _message!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.lumeColors.textSecondary,
                ),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: TextStyle(color: context.lumeColors.error),
                ),
              ),
            ),
          const SizedBox(height: 12),
          LumeButton(label: 'Guardar', isLoading: _busy, onPressed: _save),
          if (_hasDraft)
            TextButton(
              onPressed: _busy ? null : _discard,
              child: const Text('Descartar rascunho'),
            ),
          if (_original != null)
            TextButton.icon(
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Excluir entrada'),
            ),
        ],
      ),
    );
  }
}
