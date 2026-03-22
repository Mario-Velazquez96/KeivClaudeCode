import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
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

export default class CotizacionLineItems extends LightningElement {
    @api recordId;
    columns = COLUMNS;
    showNewModal = false;
    showEditModal = false;
    editRecordId = null;

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
        this.showNewModal = true;
    }

    handleNewModalClose() {
        this.showNewModal = false;
    }

    async handleNewSuccess() {
        this.showNewModal = false;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Creado',
            message: 'Partida creada correctamente.',
            variant: 'success'
        }));
        await refreshApex(this.partidas);
        getRecordNotifyChange([{ recordId: this.recordId }]);
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        if (action.name === 'edit') {
            this.editRecordId = row.Id;
            this.showEditModal = true;
        } else if (action.name === 'delete') {
            this.handleDelete(row.Id);
        }
    }

    handleEditModalClose() {
        this.showEditModal = false;
        this.editRecordId = null;
    }

    async handleEditSuccess() {
        this.showEditModal = false;
        this.editRecordId = null;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Actualizado',
            message: 'Partida actualizada correctamente.',
            variant: 'success'
        }));
        await refreshApex(this.partidas);
        getRecordNotifyChange([{ recordId: this.recordId }]);
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
            getRecordNotifyChange([{ recordId: this.recordId }]);
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'Error al eliminar la partida.',
                variant: 'error'
            }));
        }
    }
}
