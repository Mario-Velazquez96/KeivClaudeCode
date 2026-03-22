import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import getPartidasCotizacion from '@salesforce/apex/CotizacionController.getPartidasCotizacion';
import deletePartida from '@salesforce/apex/CotizacionController.deletePartida';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS = [
    { label: 'Numero', fieldName: 'Name', type: 'text' },
    { label: 'Descripcion', fieldName: 'Descripcion__c', type: 'text' },
    { label: 'Proveedor', fieldName: 'proveedorName', type: 'text' },
    { label: 'Cantidad', fieldName: 'Cantidad__c', type: 'number', typeAttributes: { minimumFractionDigits: 2 } },
    { label: 'Unidad', fieldName: 'Unidad__c', type: 'text' },
    { label: 'Costo Unit.', fieldName: 'Costo_Unitario__c', type: 'currency' },
    { label: 'Precio Unit.', fieldName: 'Precio_Unitario__c', type: 'currency' },
    { label: 'Margen %', fieldName: 'Margen_Porcentaje__c', type: 'percent', typeAttributes: { minimumFractionDigits: 2 } },
    { label: 'Total Linea', fieldName: 'Total_Linea__c', type: 'currency' },
    { label: 'Entregado', fieldName: 'Cantidad_Entregada__c', type: 'number' },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Editar', name: 'edit' },
                { label: 'Eliminar', name: 'delete' }
            ]
        }
    }
];

export default class CotizacionLineItems extends NavigationMixin(LightningElement) {
    @api recordId;
    columns = COLUMNS;

    @wire(getPartidasCotizacion, { cotizacionId: '$recordId' })
    partidas;

    get hasPartidas() {
        return this.partidas.data && this.partidas.data.length > 0;
    }

    get formattedSubtotal() {
        if (!this.partidas.data) return '$0.00';
        const subtotal = this.partidas.data.reduce((sum, p) => sum + (p.Total_Linea__c || 0), 0);
        return '$' + subtotal.toLocaleString('es-MX', { minimumFractionDigits: 2 });
    }

    get formattedIVA() {
        if (!this.partidas.data) return '$0.00';
        const subtotal = this.partidas.data.reduce((sum, p) => sum + (p.Total_Linea__c || 0), 0);
        const iva = subtotal * 0.16;
        return '$' + iva.toLocaleString('es-MX', { minimumFractionDigits: 2 });
    }

    get formattedTotal() {
        if (!this.partidas.data) return '$0.00';
        const subtotal = this.partidas.data.reduce((sum, p) => sum + (p.Total_Linea__c || 0), 0);
        const total = subtotal * 1.16;
        return '$' + total.toLocaleString('es-MX', { minimumFractionDigits: 2 });
    }

    handleNewPartida() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Partida_Cotizacion__c',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `Cotizacion__c=${this.recordId}`
            }
        });
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        if (action.name === 'edit') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.Id,
                    actionName: 'edit'
                }
            });
        } else if (action.name === 'delete') {
            this.handleDelete(row.Id);
        }
    }

    async handleDelete(partidaId) {
        try {
            await deletePartida({ partidaId: partidaId });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Eliminado',
                message: 'Partida eliminada correctamente.',
                variant: 'success'
            }));
            await refreshApex(this.partidas);
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'Error al eliminar la partida.',
                variant: 'error'
            }));
        }
    }
}
