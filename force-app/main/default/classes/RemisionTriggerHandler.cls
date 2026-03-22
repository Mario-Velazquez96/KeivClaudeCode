public class RemisionTriggerHandler {

    public static void handleAfterUpdate(List<Remision__c> newRecords, Map<Id, Remision__c> oldMap) {
        Set<Id> cotizacionIds = new Set<Id>();

        for (Remision__c rem : newRecords) {
            Remision__c oldRem = oldMap.get(rem.Id);
            if (rem.Estatus_Entrega__c != oldRem.Estatus_Entrega__c &&
                rem.Estatus_Entrega__c == Constants.ENTREGA_ENTREGADA) {
                if (rem.Cotizacion__c != null) {
                    cotizacionIds.add(rem.Cotizacion__c);
                }
            }
        }

        if (!cotizacionIds.isEmpty()) {
            EntregaService.verificarEntregaCompleta(cotizacionIds);
        }
    }
}
