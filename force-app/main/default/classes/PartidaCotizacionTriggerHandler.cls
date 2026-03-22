public class PartidaCotizacionTriggerHandler {

    public static void handleAfterInsert(List<Partida_Cotizacion__c> newRecords) {
        recalcularCotizaciones(newRecords);
    }

    public static void handleAfterUpdate(List<Partida_Cotizacion__c> newRecords, Map<Id, Partida_Cotizacion__c> oldMap) {
        recalcularCotizaciones(newRecords);
    }

    public static void handleAfterDelete(List<Partida_Cotizacion__c> oldRecords) {
        recalcularCotizaciones(oldRecords);
    }

    public static void handleAfterUndelete(List<Partida_Cotizacion__c> newRecords) {
        recalcularCotizaciones(newRecords);
    }

    private static void recalcularCotizaciones(List<Partida_Cotizacion__c> records) {
        Set<Id> cotizacionIds = new Set<Id>();
        for (Partida_Cotizacion__c pc : records) {
            if (pc.Cotizacion__c != null) {
                cotizacionIds.add(pc.Cotizacion__c);
            }
        }
        if (!cotizacionIds.isEmpty()) {
            CotizacionService.recalcularTotales(cotizacionIds);
        }
    }
}
