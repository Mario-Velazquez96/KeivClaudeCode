public class PartidaRemisionTriggerHandler {

    public static void handleAfterInsert(List<Partida_Remision__c> newRecords) {
        procesarCambiosEntrega(newRecords);
    }

    public static void handleAfterUpdate(List<Partida_Remision__c> newRecords, Map<Id, Partida_Remision__c> oldMap) {
        procesarCambiosEntrega(newRecords);
    }

    public static void handleAfterDelete(List<Partida_Remision__c> oldRecords) {
        procesarCambiosEntrega(oldRecords);
    }

    public static void handleAfterUndelete(List<Partida_Remision__c> newRecords) {
        procesarCambiosEntrega(newRecords);
    }

    private static void procesarCambiosEntrega(List<Partida_Remision__c> records) {
        Set<Id> partidaCotizacionIds = new Set<Id>();
        for (Partida_Remision__c pr : records) {
            if (pr.Partida_Cotizacion__c != null) {
                partidaCotizacionIds.add(pr.Partida_Cotizacion__c);
            }
        }

        if (partidaCotizacionIds.isEmpty()) return;

        EntregaService.recalcularCantidadesEntregadas(partidaCotizacionIds);

        Set<Id> cotizacionIds = new Set<Id>();
        for (Partida_Cotizacion__c pc : [
            SELECT Cotizacion__c FROM Partida_Cotizacion__c WHERE Id IN :partidaCotizacionIds
        ]) {
            cotizacionIds.add(pc.Cotizacion__c);
        }

        if (!cotizacionIds.isEmpty()) {
            EntregaService.verificarEntregaCompleta(cotizacionIds);
        }
    }
}
