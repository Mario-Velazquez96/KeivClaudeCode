public with sharing class PartidaOrdenCompraTriggerHandler {

    public static void handleAfter(List<Partida_Orden_Compra__c> newList, List<Partida_Orden_Compra__c> oldList) {
        Set<Id> ordenCompraIds = new Set<Id>();

        if (newList != null) {
            for (Partida_Orden_Compra__c poc : newList) {
                ordenCompraIds.add(poc.Orden_Compra__c);
            }
        }
        if (oldList != null) {
            for (Partida_Orden_Compra__c poc : oldList) {
                ordenCompraIds.add(poc.Orden_Compra__c);
            }
        }

        if (!ordenCompraIds.isEmpty()) {
            recalcularTotalOC(ordenCompraIds);
        }
    }

    private static void recalcularTotalOC(Set<Id> ordenCompraIds) {
        List<Partida_Orden_Compra__c> allPartidas = [
            SELECT Id, Orden_Compra__c, Cantidad__c, Costo_Unitario__c
            FROM Partida_Orden_Compra__c
            WHERE Orden_Compra__c IN :ordenCompraIds
        ];

        Map<Id, Decimal> totalByOC = new Map<Id, Decimal>();
        for (Id ocId : ordenCompraIds) {
            totalByOC.put(ocId, 0);
        }
        for (Partida_Orden_Compra__c poc : allPartidas) {
            Decimal cantidad = poc.Cantidad__c != null ? poc.Cantidad__c : 0;
            Decimal costo = poc.Costo_Unitario__c != null ? poc.Costo_Unitario__c : 0;
            Decimal current = totalByOC.get(poc.Orden_Compra__c);
            totalByOC.put(poc.Orden_Compra__c, current + (cantidad * costo));
        }

        List<Orden_Compra__c> toUpdate = new List<Orden_Compra__c>();
        for (Id ocId : totalByOC.keySet()) {
            toUpdate.add(new Orden_Compra__c(
                Id = ocId,
                Total__c = totalByOC.get(ocId)
            ));
        }

        update toUpdate;
    }
}
