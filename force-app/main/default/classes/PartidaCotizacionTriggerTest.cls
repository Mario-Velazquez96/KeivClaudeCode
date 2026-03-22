@isTest
private class PartidaCotizacionTriggerTest {

    @isTest
    static void testInsertPartidaRecalculaTotales() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov = TestDataFactory.createProveedor('Proveedor Test', false);
        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Contado', null);

        Test.startTest();
        TestDataFactory.createPartidaCotizacion(cot.Id, prov.Id, 10, 100, 150);
        Test.stopTest();

        cot = [SELECT Subtotal__c, Costo_Total__c FROM Cotizacion__c WHERE Id = :cot.Id];
        System.assertEquals(1500, cot.Subtotal__c);
        System.assertEquals(1000, cot.Costo_Total__c);
    }

    @isTest
    static void testUpdatePartidaRecalculaTotales() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov = TestDataFactory.createProveedor('Proveedor Test', false);
        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Contado', null);
        Partida_Cotizacion__c pc = TestDataFactory.createPartidaCotizacion(cot.Id, prov.Id, 10, 100, 150);

        Test.startTest();
        pc.Precio_Unitario__c = 200;
        update pc;
        Test.stopTest();

        cot = [SELECT Subtotal__c FROM Cotizacion__c WHERE Id = :cot.Id];
        System.assertEquals(2000, cot.Subtotal__c);
    }
}
