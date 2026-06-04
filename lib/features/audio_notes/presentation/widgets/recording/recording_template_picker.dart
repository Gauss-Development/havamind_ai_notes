import 'package:flutter/material.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';
import 'package:sample/features/audio_notes/presentation/widgets/recording/recording_tag_pill.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

/// Horizontal template chips for recording prep or idle recording screen.
class RecordingTemplatePicker extends StatelessWidget {
  const RecordingTemplatePicker({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String selectedId;
  final ValueChanged<String> onSelected;

  String _labelFor(AppLocalizations l10n, String id) {
    switch (RecordingTemplateIds.normalize(id)) {
      case RecordingTemplateIds.customerDiscovery:
        return l10n.recordingTemplateCustomerDiscovery;
      case RecordingTemplateIds.investorUpdate:
        return l10n.recordingTemplateInvestorUpdate;
      case RecordingTemplateIds.founderPitch:
      default:
        return l10n.recordingTemplateFounderPitch;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.appTokens;
    final normalizedSelected = RecordingTemplateIds.normalize(selectedId);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final id in RecordingTemplateIds.all) ...[
            if (id != RecordingTemplateIds.all.first)
              const SizedBox(width: AppSpacing.sm),
            RecordingTagPill(
              label: _labelFor(l10n, id),
              background: tokens.surfaceContainerHigh,
              foreground: tokens.onSurfaceVariant,
              selected: normalizedSelected == id,
              onTap: () => onSelected(id),
            ),
          ],
        ],
      ),
    );
  }
}
