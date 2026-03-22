import { LightningElement, api, wire } from 'lwc';
import getProveedoresParaOC from '@salesforce/apex/OrdenCompraController.getProveedoresParaOC';
import generarOrdenes from '@salesforce/apex/OrdenCompraController.generarOrdenes';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class GenerarOrdenCompra extends LightningElement {
    @api recordId;
    isGenerating = false;

    @wire(getProveedoresParaOC, { cotizacionId: '$recordId' })
    proveedores;

    get hasProveedores() {
        return this.proveedores.data && this.proveedores.data.length > 0;
    }

    async handleGenerar() {
        this.isGenerating = true;
        try {
            const ocIds = await generarOrdenes({ cotizacionId: this.recordId });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Ordenes Generadas',
                message: `Se generaron ${ocIds.length} ordenes de compra.`,
                variant: 'success'
            }));
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'Error al generar ordenes de compra.',
                variant: 'error'
            }));
        } finally {
            this.isGenerating = false;
        }
    }
}
