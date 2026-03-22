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
    static void testNoDuplicaOCsExistentes() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov1 = TestDataFactory.createProveedor('Proveedor 1', true);

        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Contado', null);

        TestDataFactory.createPartidaCotizacion(cot.Id, prov1.Id, 10, 100, 150);

        // First call - creates OC
        List<Id> ocIds1 = OrdenCompraService.generarOrdenesCompra(cot.Id);
        System.assertEquals(1, ocIds1.size(), 'Primera llamada debe crear 1 OC');

        Test.startTest();
        // Second call - should NOT create duplicates
        List<Id> ocIds2 = OrdenCompraService.generarOrdenesCompra(cot.Id);
        Test.stopTest();

        System.assertEquals(0, ocIds2.size(), 'Segunda llamada no debe crear OCs duplicadas');

        Integer totalOCs = [SELECT COUNT() FROM Orden_Compra__c WHERE Cotizacion__c = :cot.Id];
        System.assertEquals(1, totalOCs, 'Solo debe existir 1 OC para este proveedor');
    }

    @isTest
    static void testAgregaPartidasAOCExistente() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov1 = TestDataFactory.createProveedor('Proveedor 1', true);

        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Contado', null);

        // Create first partida and generate OC
        TestDataFactory.createPartidaCotizacion(cot.Id, prov1.Id, 10, 100, 150);
        List<Id> ocIds1 = OrdenCompraService.generarOrdenesCompra(cot.Id);
        System.assertEquals(1, ocIds1.size());

        // Add a new partida for the SAME proveedor
        TestDataFactory.createPartidaCotizacion(cot.Id, prov1.Id, 5, 200, 300);

        Test.startTest();
        List<Id> ocIds2 = OrdenCompraService.generarOrdenesCompra(cot.Id);
        Test.stopTest();

        // Should return the existing OC Id (updated, not new)
        System.assertEquals(1, ocIds2.size(), 'Debe actualizar 1 OC existente');
        System.assertEquals(ocIds1[0], ocIds2[0], 'Debe ser la misma OC, no una nueva');

        // Verify total OCs is still 1
        Integer totalOCs = [SELECT COUNT() FROM Orden_Compra__c WHERE Cotizacion__c = :cot.Id];
        System.assertEquals(1, totalOCs, 'Solo debe existir 1 OC');

        // Verify it now has 2 partidas
        Orden_Compra__c oc = [SELECT Id, (SELECT Id FROM Partidas_Orden_Compra__r)
            FROM Orden_Compra__c WHERE Id = :ocIds1[0]];
        System.assertEquals(2, oc.Partidas_Orden_Compra__r.size(), 'La OC debe tener 2 partidas');
    }

    @isTest
    static void testNuevoProveedorCreaOCNueva() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov1 = TestDataFactory.createProveedor('Proveedor 1', true);
        Proveedor__c prov2 = TestDataFactory.createProveedor('Proveedor 2', true);

        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Contado', null);

        // Generate OC for prov1
        TestDataFactory.createPartidaCotizacion(cot.Id, prov1.Id, 10, 100, 150);
        OrdenCompraService.generarOrdenesCompra(cot.Id);

        // Add partida for a NEW proveedor
        TestDataFactory.createPartidaCotizacion(cot.Id, prov2.Id, 20, 50, 75);

        Test.startTest();
        List<Id> ocIds = OrdenCompraService.generarOrdenesCompra(cot.Id);
        Test.stopTest();

        System.assertEquals(1, ocIds.size(), 'Debe crear 1 OC nueva para prov2');

        Integer totalOCs = [SELECT COUNT() FROM Orden_Compra__c WHERE Cotizacion__c = :cot.Id];
        System.assertEquals(2, totalOCs, 'Deben existir 2 OCs en total');
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

    @isTest
    static void testGetEstadoOrdenesTodasCubiertas() {
        Account acc = TestDataFactory.createAccount('Cliente Test');
        Proveedor__c prov1 = TestDataFactory.createProveedor('Proveedor 1', true);

        Cotizacion__c cot = TestDataFactory.createCotizacion(acc.Id, 'Contado', null);
        TestDataFactory.createPartidaCotizacion(cot.Id, prov1.Id, 10, 100, 150);

        OrdenCompraService.generarOrdenesCompra(cot.Id);

        Test.startTest();
        Map<String, Object> estado = OrdenCompraController.getEstadoOrdenes(cot.Id);
        Test.stopTest();

        System.assertEquals(true, estado.get('todasCubiertas'), 'Todas las partidas deben estar cubiertas');
        System.assertEquals(1, estado.get('totalPartidas'));
        System.assertEquals(1, estado.get('partidasCubiertas'));
        List<Object> pendientes = (List<Object>) estado.get('proveedoresPendientes');
        System.assertEquals(0, pendientes.size(), 'No debe haber proveedores pendientes');
    }
}
