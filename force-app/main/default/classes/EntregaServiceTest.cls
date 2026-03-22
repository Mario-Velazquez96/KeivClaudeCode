@isTest
private class EntregaServiceTest {

    @isTest
    static void testEntregaParcial() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov = TestDataFactory.createProveedor('Proveedor Test', false);
        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Credito', 30);
        Partida_Cotizacion__c pc = TestDataFactory.createPartidaCotizacion(cot.Id, prov.Id, 10, 100, 150);

        Remision__c rem = TestDataFactory.createRemision(cot.Id);

        Test.startTest();
        TestDataFactory.createPartidaRemision(rem.Id, pc.Id, 5);
        Test.stopTest();

        pc = [SELECT Cantidad_Entregada__c, Cantidad_Pendiente__c FROM Partida_Cotizacion__c WHERE Id = :pc.Id];
        System.assertEquals(5, pc.Cantidad_Entregada__c, 'Cantidad entregada incorrecta');
        System.assertEquals(5, pc.Cantidad_Pendiente__c, 'Cantidad pendiente incorrecta');

        cot = [SELECT Fecha_Entrega_Completa__c FROM Cotizacion__c WHERE Id = :cot.Id];
        System.assertEquals(null, cot.Fecha_Entrega_Completa__c, 'No debe tener fecha de entrega completa');
    }

    @isTest
    static void testEntregaCompleta() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov = TestDataFactory.createProveedor('Proveedor Test', false);
        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Credito', 30);
        Partida_Cotizacion__c pc = TestDataFactory.createPartidaCotizacion(cot.Id, prov.Id, 10, 100, 150);

        Remision__c rem = TestDataFactory.createRemision(cot.Id);

        Test.startTest();
        TestDataFactory.createPartidaRemision(rem.Id, pc.Id, 10);
        Test.stopTest();

        cot = [SELECT Fecha_Entrega_Completa__c, Estatus__c FROM Cotizacion__c WHERE Id = :cot.Id];
        System.assertNotEquals(null, cot.Fecha_Entrega_Completa__c, 'Debe tener fecha de entrega completa');
        System.assertEquals(Date.today(), cot.Fecha_Entrega_Completa__c);
    }

    @isTest
    static void testEntregaCompletaMultiplesPartidas() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov = TestDataFactory.createProveedor('Proveedor Test', false);
        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Contado', null);
        Partida_Cotizacion__c pc1 = TestDataFactory.createPartidaCotizacion(cot.Id, prov.Id, 10, 100, 150);
        Partida_Cotizacion__c pc2 = TestDataFactory.createPartidaCotizacion(cot.Id, prov.Id, 5, 200, 300);

        Remision__c rem1 = TestDataFactory.createRemision(cot.Id);
        TestDataFactory.createPartidaRemision(rem1.Id, pc1.Id, 10);

        cot = [SELECT Fecha_Entrega_Completa__c FROM Cotizacion__c WHERE Id = :cot.Id];
        System.assertEquals(null, cot.Fecha_Entrega_Completa__c, 'No todas las partidas estan entregadas');

        Remision__c rem2 = TestDataFactory.createRemision(cot.Id);

        Test.startTest();
        TestDataFactory.createPartidaRemision(rem2.Id, pc2.Id, 5);
        Test.stopTest();

        cot = [SELECT Fecha_Entrega_Completa__c FROM Cotizacion__c WHERE Id = :cot.Id];
        System.assertNotEquals(null, cot.Fecha_Entrega_Completa__c, 'Todas las partidas entregadas');
    }
}
