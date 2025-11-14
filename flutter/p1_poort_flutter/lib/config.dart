class InfluxConfig {
  static const String kInlfuxDbUrl = "https://eu-central-1-1.aws.cloud2.influxdata.com";
  static const String kInfluxDbOrg = "e98e1f61e09dcc78";
  static const String kInfluxDbBucket = "dsmr";
  static const String kInfluxDbToken = "B-JyGFDmkz8KBCSrkySyxD7FzjQy7gGhBjo9i466vY_-LRzHgVCH6mOGr2jpoOP1eJ4dRtOQm6SvLN7ke3fLzg==";

  static const String kMeasurement = "dsmr_data";
  static const String kCurrentInjectionField = "huidige_injectie";
  static const String kCurrentUsageField = "huidig_verbruik";

  static const String tariffField = "actief_tarief__numeriek_";
  static const String kActiveEnergyImportCurrentAverageDemandField = "huidige_gemiddelde_kwartierverbruik_voor_capaciteitstarief";
  static const String kActiveEnergyImportMaximumDemandRunningMonthField = "maximale_kwartierverbruik_voor_capaciteitstarief_voor_de_huidige_maand";
  static const String kActiveEnergyImportMaximumDemandLast13Months = "maximale_kwartierverbruik_voor_capaciteitstarief_voor_de_afgelopen_13_maanden";

  static const String energyField = "kwh_consumed";
}