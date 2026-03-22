List<Orden_Compra__c> ocs = [SELECT Id FROM Orden_Compra__c WHERE Total__c = 0];
Set<Id> ocIds = new Set<Id>();
for (Orden_Compra__c oc : ocs) {
    ocIds.add(oc.Id);
}
if (!ocIds.isEmpty()) {
    List<Partida_Orden_Compra__c> pocs = [
        SELECT Id, Orden_Compra__c, Cantidad__c, Costo_Unitario__c
        FROM Partida_Orden_Compra__c
        WHERE Orden_Compra__c IN :ocIds
    ];
    Map<Id, Decimal> totalByOC = new Map<Id, Decimal>();
    for (Id ocId : ocIds) {
        totalByOC.put(ocId, 0);
    }
    for (Partida_Orden_Compra__c poc : pocs) {
        Decimal c = poc.Cantidad__c != null ? poc.Cantidad__c : 0;
        Decimal u = poc.Costo_Unitario__c != null ? poc.Costo_Unitario__c : 0;
        totalByOC.put(poc.Orden_Compra__c, totalByOC.get(poc.Orden_Compra__c) + (c * u));
    }
    List<Orden_Compra__c> toUpdate = new List<Orden_Compra__c>();
    for (Id ocId : totalByOC.keySet()) {
        toUpdate.add(new Orden_Compra__c(Id = ocId, Total__c = totalByOC.get(ocId)));
    }
    update toUpdate;
    System.debug('Updated ' + toUpdate.size() + ' OCs');
} else {
    System.debug('No OCs with Total = 0 found');
}
