@isTest
private class CotizacionServiceTest {

    @isTest
    static void testRecalcularTotales() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov = TestDataFactory.createProveedor('Proveedor Test', false);
        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Contado', null);

        TestDataFactory.createPartidaCotizacion(cot.Id, prov.Id, 10, 100, 135);
        TestDataFactory.createPartidaCotizacion(cot.Id, prov.Id, 5, 200, 270);

        cot = [SELECT Subtotal__c, IVA__c, Total__c, Costo_Total__c, Utilidad__c, Margen_Promedio__c
               FROM Cotizacion__c WHERE Id = :cot.Id];

        Decimal expectedSubtotal = (10 * 135) + (5 * 270);
        Decimal expectedCosto = (10 * 100) + (5 * 200);
        Decimal expectedIVA = expectedSubtotal * 0.16;
        Decimal expectedTotal = expectedSubtotal + expectedIVA;

        System.assertEquals(expectedSubtotal, cot.Subtotal__c, 'Subtotal incorrecto');
        System.assertEquals(expectedCosto, cot.Costo_Total__c, 'Costo total incorrecto');
        System.assertEquals(expectedIVA, cot.IVA__c, 'IVA incorrecto');
        System.assertEquals(expectedTotal, cot.Total__c, 'Total incorrecto');
    }

    @isTest
    static void testRecalcularTotalesAfterDelete() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov = TestDataFactory.createProveedor('Proveedor Test', false);
        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Contado', null);

        Partida_Cotizacion__c pc1 = TestDataFactory.createPartidaCotizacion(cot.Id, prov.Id, 10, 100, 135);
        Partida_Cotizacion__c pc2 = TestDataFactory.createPartidaCotizacion(cot.Id, prov.Id, 5, 200, 270);

        Test.startTest();
        delete pc2;
        Test.stopTest();

        cot = [SELECT Subtotal__c, Costo_Total__c FROM Cotizacion__c WHERE Id = :cot.Id];

        System.assertEquals(10 * 135, cot.Subtotal__c, 'Subtotal after delete incorrecto');
        System.assertEquals(10 * 100, cot.Costo_Total__c, 'Costo after delete incorrecto');
    }

    @isTest
    static void testRecalcularTotalesEmpty() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Contado', null);

        Test.startTest();
        CotizacionService.recalcularTotales(new Set<Id>{cot.Id});
        Test.stopTest();

        cot = [SELECT Subtotal__c, Total__c FROM Cotizacion__c WHERE Id = :cot.Id];
        System.assertEquals(0, cot.Subtotal__c);
        System.assertEquals(0, cot.Total__c);
    }
}
