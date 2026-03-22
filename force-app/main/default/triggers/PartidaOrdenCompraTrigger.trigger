trigger PartidaOrdenCompraTrigger on Partida_Orden_Compra__c (after insert, after update, after delete, after undelete) {
    PartidaOrdenCompraTriggerHandler.handleAfter(Trigger.new, Trigger.old);
}
