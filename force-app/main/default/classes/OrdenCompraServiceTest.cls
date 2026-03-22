@isTest
private class OrdenCompraServiceTest {

    @isTest
    static void testGenerarOrdenesCompra() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov1 = TestDataFactory.createProveedor('Proveedor 1', true);
        Proveedor__c prov2 = TestDataFactory.createProveedor('Proveedor 2', true);
        Proveedor__c prov3 = TestDataFactory.createProveedor('Proveedor 3', false);

        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Contado', null);

        TestDataFactory.createPartidaCotizacion(cot.Id, prov1.Id, 10, 100, 150);
        TestDataFactory.createPartidaCotizacion(cot.Id, prov1.Id, 5, 200, 300);
        TestDataFactory.createPartidaCotizacion(cot.Id, prov2.Id, 20, 50, 75);
        TestDataFactory.createPartidaCotizacion(cot.Id, prov3.Id, 3, 500, 700);

        Test.startTest();
        List<Id> ocIds = OrdenCompraService.generarOrdenesCompra(cot.Id);
        Test.stopTest();

        System.assertEquals(2, ocIds.size(), 'Debe generar 2 OCs (solo proveedores que requieren OC)');

        List<Orden_Compra__c> ocs = [SELECT Id, Proveedor__c,
            (SELECT Id FROM Partidas_Orden_Compra__r)
            FROM Orden_Compra__c WHERE Id IN :ocIds];

        for (Orden_Compra__c oc : ocs) {
            if (oc.Proveedor__c == prov1.Id) {
                System.assertEquals(2, oc.Partidas_Orden_Compra__r.size(), 'Proveedor 1 debe tener 2 partidas');
            } else if (oc.Proveedor__c == prov2.Id) {
                System.assertEquals(1, oc.Partidas_Orden_Compra__r.size(), 'Proveedor 2 debe tener 1 partida');
            }
        }
    }

    @isTest
    static void testNoGenerarOCSinProveedores() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Contado', null);

        Test.startTest();
        List<Id> ocIds = OrdenCompraService.generarOrdenesCompra(cot.Id);
        Test.stopTest();

        System.assertEquals(0, ocIds.size(), 'No debe generar OCs sin partidas');
    }
}
