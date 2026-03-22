@isTest
private class CreditoVencidoSchedulableTest {

    @isTest
    static void testSchedulableExecution() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov = TestDataFactory.createProveedor('Proveedor Test', false);
        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Credito', 30);
        TestDataFactory.createPartidaCotizacion(cot.Id, prov.Id, 10, 100, 150);

        Remision__c rem = TestDataFactory.createRemision(cot.Id);
        Partida_Cotizacion__c pc = [SELECT Id FROM Partida_Cotizacion__c WHERE Cotizacion__c = :cot.Id LIMIT 1];
        TestDataFactory.createPartidaRemision(rem.Id, pc.Id, 10);

        cot = [SELECT Fecha_Entrega_Completa__c FROM Cotizacion__c WHERE Id = :cot.Id];
        cot.Fecha_Entrega_Completa__c = Date.today().addDays(-60);
        update cot;

        Test.startTest();
        CreditoVencidoSchedulable schedulable = new CreditoVencidoSchedulable();
        schedulable.execute(null);
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject FROM Task WHERE WhatId = :cot.Id AND Subject LIKE 'Credito vencido%'];
        System.assert(tasks.size() > 0, 'Debe crear al menos una tarea de cobranza');
    }
}
