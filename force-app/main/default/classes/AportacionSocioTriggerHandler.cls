public class AportacionSocioTriggerHandler {

    public static Boolean skipRecalculation = false;

    public static void handleAfterInsert(List<Aportacion_Socio__c> newRecords) {
        if (!skipRecalculation) {
            recalcular(newRecords);
        }
    }

    public static void handleAfterUpdate(List<Aportacion_Socio__c> newRecords, Map<Id, Aportacion_Socio__c> oldMap) {
        if (!skipRecalculation) {
            recalcular(newRecords);
        }
    }

    public static void handleAfterDelete(List<Aportacion_Socio__c> oldRecords) {
        if (!skipRecalculation) {
            recalcular(oldRecords);
        }
    }

    private static void recalcular(List<Aportacion_Socio__c> records) {
        Set<Id> cotizacionIds = new Set<Id>();
        for (Aportacion_Socio__c ap : records) {
            if (ap.Cotizacion__c != null) {
                cotizacionIds.add(ap.Cotizacion__c);
            }
        }
        if (!cotizacionIds.isEmpty()) {
            AportacionSocioService.recalcularDistribucion(cotizacionIds);
        }
    }
}
