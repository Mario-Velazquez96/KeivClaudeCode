import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getEstadoOrdenes from '@salesforce/apex/OrdenCompraController.getEstadoOrdenes';
import generarOrdenes from '@salesforce/apex/OrdenCompraController.generarOrdenes';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class GenerarOrdenCompra extends LightningElement {
    @api recordId;
    isGenerating = false;
    _wiredResult;

    @wire(getEstadoOrdenes, { cotizacionId: '$recordId' })
    wiredEstado(result) {
        this._wiredResult = result;
    }

    get estado() {
        return this._wiredResult?.data;
    }

    get hasError() {
        return !!this._wiredResult?.error;
    }

    get proveedoresPendientes() {
        return this.estado?.proveedoresPendientes || [];
    }

    get hasProveedoresPendientes() {
        return this.proveedoresPendientes.length > 0;
    }

    get todasCubiertas() {
        return this.estado?.todasCubiertas === true;
    }

    get noRequierenOC() {
        return this.estado && !this.todasCubiertas && !this.hasProveedoresPendientes
            && this.estado.totalPartidas === 0;
    }

    get isButtonDisabled() {
        return this.isGenerating || this.todasCubiertas || !this.hasProveedoresPendientes;
    }

    async handleGenerar() {
        this.isGenerating = true;
        try {
            const ocIds = await generarOrdenes({ cotizacionId: this.recordId });
            const msg = ocIds.length > 0
                ? `Se generaron/actualizaron ${ocIds.length} ordenes de compra.`
                : 'No hay partidas pendientes para generar ordenes.';
            this.dispatchEvent(new ShowToastEvent({
                title: 'Ordenes Generadas',
                message: msg,
                variant: 'success'
            }));
            await refreshApex(this._wiredResult);
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
