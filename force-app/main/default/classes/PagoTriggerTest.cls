@isTest
private class PagoTriggerTest {

    @isTest
    static void testPagoActualizaMontoPagado() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov = TestDataFactory.createProveedor('Proveedor Test', false);
        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Credito', 30);
        TestDataFactory.createPartidaCotizacion(cot.Id, prov.Id, 10, 100, 150);

        Test.startTest();
        TestDataFactory.createPago(cot.Id, 500);
        TestDataFactory.createPago(cot.Id, 300);
        Test.stopTest();

        cot = [SELECT Monto_Pagado__c, Saldo_Pendiente__c FROM Cotizacion__c WHERE Id = :cot.Id];
        System.assertEquals(800, cot.Monto_Pagado__c, 'Monto pagado incorrecto');
    }

    @isTest
    static void testDeletePagoRecalcula() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov = TestDataFactory.createProveedor('Proveedor Test', false);
        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Credito', 30);
        TestDataFactory.createPartidaCotizacion(cot.Id, prov.Id, 10, 100, 150);

        Pago__c p1 = TestDataFactory.createPago(cot.Id, 500);
        Pago__c p2 = TestDataFactory.createPago(cot.Id, 300);

        Test.startTest();
        delete p2;
        Test.stopTest();

        cot = [SELECT Monto_Pagado__c FROM Cotizacion__c WHERE Id = :cot.Id];
        System.assertEquals(500, cot.Monto_Pagado__c, 'Monto pagado after delete incorrecto');
    }
}
