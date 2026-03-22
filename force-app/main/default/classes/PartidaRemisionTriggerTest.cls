@isTest
private class PartidaRemisionTriggerTest {

    @isTest
    static void testInsertPartidaRemisionActualizaCantidad() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov = TestDataFactory.createProveedor('Proveedor Test', false);
        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Contado', null);
        Partida_Cotizacion__c pc = TestDataFactory.createPartidaCotizacion(cot.Id, prov.Id, 10, 100, 150);

        Remision__c rem = TestDataFactory.createRemision(cot.Id);

        Test.startTest();
        TestDataFactory.createPartidaRemision(rem.Id, pc.Id, 3);
        Test.stopTest();

        pc = [SELECT Cantidad_Entregada__c FROM Partida_Cotizacion__c WHERE Id = :pc.Id];
        System.assertEquals(3, pc.Cantidad_Entregada__c);
    }

    @isTest
    static void testDeletePartidaRemisionRecalcula() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov = TestDataFactory.createProveedor('Proveedor Test', false);
        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Contado', null);
        Partida_Cotizacion__c pc = TestDataFactory.createPartidaCotizacion(cot.Id, prov.Id, 10, 100, 150);

        Remision__c rem = TestDataFactory.createRemision(cot.Id);
        Partida_Remision__c pr = TestDataFactory.createPartidaRemision(rem.Id, pc.Id, 5);

        Test.startTest();
        delete pr;
        Test.stopTest();

        pc = [SELECT Cantidad_Entregada__c FROM Partida_Cotizacion__c WHERE Id = :pc.Id];
        System.assertEquals(0, pc.Cantidad_Entregada__c);
    }
}
