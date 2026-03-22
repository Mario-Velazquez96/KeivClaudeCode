@isTest
private class AportacionSocioServiceTest {

    @isTest
    static void testDistribucionUtilidad() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov = TestDataFactory.createProveedor('Proveedor Test', false);
        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Contado', null);

        TestDataFactory.createPartidaCotizacion(cot.Id, prov.Id, 1, 100000, 135000);

        Test.startTest();
        Aportacion_Socio__c apMario = TestDataFactory.createAportacion(cot.Id, 'Mario', 70000);
        Aportacion_Socio__c apElliot = TestDataFactory.createAportacion(cot.Id, 'Elliot', 30000);
        Test.stopTest();

        apMario = [SELECT Porcentaje_Inversion__c, Monto_Utilidad__c, Retorno_Total__c
                   FROM Aportacion_Socio__c WHERE Id = :apMario.Id];
        apElliot = [SELECT Porcentaje_Inversion__c, Monto_Utilidad__c, Retorno_Total__c
                    FROM Aportacion_Socio__c WHERE Id = :apElliot.Id];

        System.assertEquals(70, apMario.Porcentaje_Inversion__c, 'Mario debe tener 70%');
        System.assertEquals(30, apElliot.Porcentaje_Inversion__c, 'Elliot debe tener 30%');

        Decimal utilidad = 135000 - 100000;
        System.assertEquals(utilidad * 0.70, apMario.Monto_Utilidad__c, 'Utilidad Mario incorrecta');
        System.assertEquals(utilidad * 0.30, apElliot.Monto_Utilidad__c, 'Utilidad Elliot incorrecta');
    }

    @isTest
    static void testSocioUnico() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov = TestDataFactory.createProveedor('Proveedor Test', false);
        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Contado', null);

        TestDataFactory.createPartidaCotizacion(cot.Id, prov.Id, 1, 100000, 135000);

        Test.startTest();
        Aportacion_Socio__c apMario = TestDataFactory.createAportacion(cot.Id, 'Mario', 100000);
        Test.stopTest();

        apMario = [SELECT Porcentaje_Inversion__c, Monto_Utilidad__c
                   FROM Aportacion_Socio__c WHERE Id = :apMario.Id];

        System.assertEquals(100, apMario.Porcentaje_Inversion__c, 'Mario debe tener 100%');
    }
}
