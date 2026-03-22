public class PagoTriggerHandler {

    public static void handleAfterInsert(List<Pago__c> newRecords) {
        recalcularPagos(newRecords);
    }

    public static void handleAfterUpdate(List<Pago__c> newRecords, Map<Id, Pago__c> oldMap) {
        recalcularPagos(newRecords);
    }

    public static void handleAfterDelete(List<Pago__c> oldRecords) {
        recalcularPagos(oldRecords);
    }

    public static void handleAfterUndelete(List<Pago__c> newRecords) {
        recalcularPagos(newRecords);
    }

    private static void recalcularPagos(List<Pago__c> records) {
        Set<Id> cotizacionIds = new Set<Id>();
        for (Pago__c p : records) {
            if (p.Cotizacion__c != null) {
                cotizacionIds.add(p.Cotizacion__c);
            }
        }
        if (!cotizacionIds.isEmpty()) {
            CotizacionService.recalcularMontoPagado(cotizacionIds);
        }
    }
}
