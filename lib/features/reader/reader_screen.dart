import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reader_controller.dart';
import 'reader_settings.dart';
import 'paged_reader.dart';
import 'vertical_reader.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String seriesId;
  final int initialPage;

  const ReaderScreen({
    super.key,
    required this.seriesId,
    this.initialPage = 0,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _showUi = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = (widget.seriesId, widget.initialPage);
    final asyncState = ref.watch(readerControllerProvider(key));
    final ctrl = ref.read(readerControllerProvider(key).notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(e.toString(), style: const TextStyle(color: Colors.white70)),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
        data: (state) => Stack(
          children: [
            // Main reader content
            state.settings.mode == ReadingMode.vertical
                ? VerticalReader(
                    readerState: state,
                    getPageBytes: ctrl.getPageBytes,
                    onTapCenter: _toggleUi,
                  )
                : PagedReader(
                    readerState: state,
                    getPageBytes: ctrl.getPageBytes,
                    onTapLeft: ctrl.prevPage,
                    onTapRight: ctrl.nextPage,
                    onTapCenter: _toggleUi,
                  ),

            // Overlay UI
            AnimatedOpacity(
              opacity: _showUi ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showUi,
                child: _ReaderOverlay(
                  state: state,
                  onClose: () => Navigator.of(context).pop(),
                  onSettingsChanged: ctrl.updateSettings,
                  onPageChanged: ctrl.goToPage,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleUi() => setState(() => _showUi = !_showUi);
}

class _ReaderOverlay extends StatelessWidget {
  final ReaderState state;
  final VoidCallback onClose;
  final void Function(ReaderSettings) onSettingsChanged;
  final void Function(int) onPageChanged;

  const _ReaderOverlay({
    required this.state,
    required this.onClose,
    required this.onSettingsChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top bar
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: onClose,
                ),
                Expanded(
                  child: Text(
                    'Page ${state.currentPage + 1} / ${state.pageCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () => _showSettings(context),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        // Bottom bar — page slider
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Row(
            children: [
              Text(
                '${state.currentPage + 1}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Expanded(
                child: Slider(
                  value: state.currentPage.toDouble(),
                  min: 0,
                  max: (state.pageCount - 1).toDouble(),
                  onChanged: (v) => onPageChanged(v.round()),
                  activeColor: Colors.white,
                  inactiveColor: Colors.white30,
                ),
              ),
              Text(
                '${state.pageCount}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (_) => _SettingsSheet(
        settings: state.settings,
        onChanged: onSettingsChanged,
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  final ReaderSettings settings;
  final void Function(ReaderSettings) onChanged;

  const _SettingsSheet({required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reader Settings',
              style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          // Reading mode
          Row(
            children: [
              const Text('Mode:', style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('Paged'),
                selected: settings.mode == ReadingMode.paged,
                onSelected: (_) =>
                    onChanged(settings.copyWith(mode: ReadingMode.paged)),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Vertical'),
                selected: settings.mode == ReadingMode.vertical,
                onSelected: (_) =>
                    onChanged(settings.copyWith(mode: ReadingMode.vertical)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Direction
          if (settings.mode == ReadingMode.paged)
            Row(
              children: [
                const Text('Direction:', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('LTR'),
                  selected: settings.direction == ReadingDirection.ltr,
                  onSelected: (_) => onChanged(
                      settings.copyWith(direction: ReadingDirection.ltr)),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('RTL'),
                  selected: settings.direction == ReadingDirection.rtl,
                  onSelected: (_) => onChanged(
                      settings.copyWith(direction: ReadingDirection.rtl)),
                ),
              ],
            ),
          const SizedBox(height: 12),
          // Night mode
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Night mode', style: TextStyle(color: Colors.white)),
            value: settings.nightMode,
            onChanged: (v) => onChanged(settings.copyWith(nightMode: v)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
