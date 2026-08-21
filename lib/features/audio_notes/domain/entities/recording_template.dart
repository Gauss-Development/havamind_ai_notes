/// MVP recording templates — same analysis JSON schema, different on-record prompts
/// and edge-function analysis instructions.
abstract final class RecordingTemplateIds {
  static const founderPitch = 'founder_pitch';
  static const customerDiscovery = 'customer_discovery';
  static const investorUpdate = 'investor_update';

  static const List<String> all = [
    founderPitch,
    customerDiscovery,
    investorUpdate,
  ];

  static bool isValid(String? id) => id != null && all.contains(id);

  static String normalize(String? id) => isValid(id) ? id! : founderPitch;
}
