# Solución Salesforce: Sistema de Gestión para Intermediario Comercial

## Contexto del Negocio

La empresa opera como **intermediario comercial** vendiendo productos a empresas petroleras y navieras. No maneja inventario propio ni desarrolla productos: recibe solicitudes de cotización de clientes, busca proveedores externos, agrega un margen de ganancia y vende al cliente final.

### Características clave del negocio
- No existe un catálogo fijo de productos
- El margen no es fijo (rango histórico: 25-35%, pero puede variar por negociación)
- El proveedor se elige normalmente por precio
- IVA aplicable: 16% sobre la venta
- Dos socios (Mario y Elliot) reparten la utilidad según su inversión por operación
- El crédito inicia **únicamente** cuando el pedido completo ha sido entregado

---

## Arquitectura de la Solución

### Tecnologías utilizadas
- **Salesforce DX** (formato source, API v58.0)
- **Apex** (lógica de negocio, triggers, servicios)
- **Lightning Web Components** (interfaz de usuario)
- **Metadata XML** (configuración declarativa)

### Patrón de diseño Apex
Se sigue el patrón **Trigger → Handler → Service**:
1. **Trigger**: Contiene cero lógica, solo delega al handler
2. **Handler**: Identifica los registros afectados y llama al servicio
3. **Service**: Contiene toda la lógica de negocio reutilizable

---

## Modelo de Datos

### Diagrama de Relaciones

```
Account (Cliente)
  └── Cotizacion__c (COT-0001)
        │
        ├── Partida_Cotizacion__c (PC-00001) ──► Proveedor__c
        │     ├── (referenciada por) Partida_Orden_Compra__c
        │     └── (referenciada por) Partida_Remision__c
        │
        ├── Orden_Compra__c (OC-0001) ──► Proveedor__c
        │     └── Partida_Orden_Compra__c (POC-00001)
        │
        ├── Remision__c (REM-0001)
        │     └── Partida_Remision__c (PR-00001)
        │
        ├── Aportacion_Socio__c (AP-00001)
        │
        └── Pago__c (PAG-0001)
```

### Objetos Custom

#### 1. Proveedor__c (Proveedor)
Almacena la información de los proveedores externos.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| Name | Text(80) | Nombre del proveedor |
| Contacto__c | Text(255) | Persona de contacto |
| Telefono__c | Phone | Teléfono |
| Email__c | Email | Correo electrónico |
| Direccion__c | TextArea | Dirección fiscal |
| Requiere_Orden_Compra__c | Checkbox | Indica si este proveedor necesita OC formal |
| Notas__c | LongTextArea | Notas generales |
| Activo__c | Checkbox | Si el proveedor está activo (default: true) |

#### 2. Cotizacion__c (Cotización)
Objeto central del sistema. Representa una cotización al cliente y funciona como expediente único de toda la operación.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| Name | AutoNumber (COT-{0000}) | Número de cotización |
| Cuenta__c | Lookup(Account) | Cliente (obligatorio) |
| Fecha__c | Date | Fecha de la cotización |
| Moneda__c | Picklist (MXN/USD) | Moneda de la operación |
| Tipo_Cambio__c | Number(16,4) | Tipo de cambio (default: 1) |
| Condicion_Pago__c | Picklist | Contado o Crédito |
| Dias_Credito__c | Number(3,0) | Días de crédito (30, 60, 90, etc.) |
| Fecha_Entrega__c | Date | Fecha estimada de entrega |
| Plazo_Entrega__c | Text(255) | Descripción del plazo (ej: "3-5 días hábiles") |
| Observaciones__c | LongTextArea | Notas y condiciones |
| Estatus__c | Picklist | Estado del flujo (ver abajo) |
| **Campos calculados** | | |
| Subtotal__c | Currency | Suma de Total_Linea de todas las partidas (trigger) |
| IVA__c | Currency | Subtotal × 0.16 (trigger) |
| Total__c | Currency | Subtotal + IVA (trigger) |
| Costo_Total__c | Currency | Suma de costos de todas las partidas (trigger) |
| Utilidad__c | Currency | Subtotal - Costo_Total (fórmula) |
| Margen_Promedio__c | Percent | (Subtotal - Costo) / Costo (fórmula) |
| Fecha_Entrega_Completa__c | Date | Se auto-establece cuando TODAS las partidas están entregadas |
| Fecha_Vencimiento_Credito__c | Date | Fecha_Entrega_Completa + Dias_Credito (fórmula) |
| Monto_Pagado__c | Currency | Suma de todos los pagos (trigger) |
| Saldo_Pendiente__c | Currency | Total - Monto_Pagado (fórmula) |
| Credito_Vencido__c | Checkbox | true si es crédito, venció y tiene saldo (fórmula) |

**Valores del estatus:**
`Borrador` → `Enviada` → `Aceptada` → `En Proceso` → `Entregada` → `Cobrada`
También: `Rechazada`, `Cancelada`

**Reglas de validación:**
- `Dias_Credito_Requerido`: Si la condición es Crédito, los días de crédito son obligatorios
- `Dias_Credito_Solo_Credito`: Los días de crédito solo aplican cuando es Crédito

#### 3. Partida_Cotizacion__c (Partida de Cotización)
Cada línea de producto/servicio dentro de una cotización.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| Name | AutoNumber (PC-{00000}) | Número de partida |
| Cotizacion__c | Master-Detail | Cotización padre |
| Proveedor__c | Lookup | Proveedor de este producto |
| Descripcion__c | TextArea | Descripción del producto/servicio |
| Cantidad__c | Number(10,2) | Cantidad solicitada |
| Unidad__c | Picklist | Pieza, Litro, Kilo, Metro, Servicio, Otro |
| Costo_Unitario__c | Currency(16,4) | Costo del proveedor |
| Precio_Unitario__c | Currency(16,4) | Precio al cliente |
| **Campos calculados** | | |
| Margen_Porcentaje__c | Percent (fórmula) | (Precio - Costo) / Costo |
| Total_Linea__c | Currency (fórmula) | Cantidad × Precio |
| Costo_Total_Linea__c | Currency (fórmula) | Cantidad × Costo |
| Estatus_Proveedor__c | Picklist | Pendiente, Cotizado, Confirmado, En Tránsito, Recibido |
| Cantidad_Entregada__c | Number | Total entregado al cliente (actualizado por trigger) |
| Cantidad_Pendiente__c | Number (fórmula) | Cantidad - Cantidad_Entregada |
| Entrega_Completa__c | Checkbox (fórmula) | true si Entregada ≥ Cantidad |

**Reglas de validación:**
- `Precio_Mayor_Cero`: El precio unitario debe ser mayor a cero
- `Cantidad_Mayor_Cero`: La cantidad debe ser mayor a cero

#### 4. Orden_Compra__c (Orden de Compra)
Se genera una OC por cada proveedor que lo requiera, agrupando las partidas de ese proveedor.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| Name | AutoNumber (OC-{0000}) | Número de OC |
| Cotizacion__c | Lookup | Cotización origen |
| Proveedor__c | Lookup | Proveedor destinatario |
| Fecha__c | Date | Fecha de la OC |
| Estatus__c | Picklist | Borrador, Enviada, Confirmada, Parcialmente Recibida, Recibida, Cancelada |
| Total__c | Currency | Total de la OC (trigger) |
| Notas__c | LongTextArea | Notas |

#### 5. Partida_Orden_Compra__c (Partida de OC)
Líneas dentro de una orden de compra, vinculadas a las partidas originales de la cotización.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| Name | AutoNumber (POC-{00000}) | Número de partida OC |
| Orden_Compra__c | Master-Detail | OC padre |
| Partida_Cotizacion__c | Lookup | Partida original de cotización |
| Descripcion__c | TextArea | Descripción |
| Cantidad__c | Number(10,2) | Cantidad |
| Unidad__c | Text(50) | Unidad |
| Costo_Unitario__c | Currency(16,4) | Costo unitario |
| Total_Linea__c | Currency (fórmula) | Cantidad × Costo |

#### 6. Remision__c (Remisión / Nota de Entrega)
Documenta cada entrega al cliente. Una cotización puede tener múltiples remisiones (entregas parciales).

| Campo | Tipo | Descripción |
|-------|------|-------------|
| Name | AutoNumber (REM-{0000}) | Número de remisión |
| Cotizacion__c | Lookup | Cotización origen |
| Fecha__c | Date | Fecha de entrega |
| Estatus_Entrega__c | Picklist | Pendiente, En Tránsito, Entregada |
| Firmada__c | Checkbox | Si el cliente firmó la remisión |
| Notas__c | LongTextArea | Notas |

#### 7. Partida_Remision__c (Partida de Remisión)
Detalle de qué cantidad de cada partida se entregó en esta remisión.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| Name | AutoNumber (PR-{00000}) | Número |
| Remision__c | Master-Detail | Remisión padre |
| Partida_Cotizacion__c | Lookup | Partida original de cotización |
| Cantidad_Entregada__c | Number(10,2) | Cantidad entregada |

#### 8. Aportacion_Socio__c (Aportación de Socio)
Registra la inversión de cada socio en una operación específica.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| Name | AutoNumber (AP-{00000}) | Número |
| Cotizacion__c | Lookup | Cotización |
| Socio__c | Picklist | Mario o Elliot |
| Monto_Inversion__c | Currency | Monto invertido |
| Porcentaje_Inversion__c | Percent | % sobre inversión total (trigger) |
| Monto_Utilidad__c | Currency | Utilidad que le corresponde (trigger) |
| Retorno_Total__c | Currency (fórmula) | Inversión + Utilidad |

**Regla de validación:**
- `Inversion_Mayor_Cero`: El monto de inversión debe ser mayor a cero

**Ejemplo del cálculo:**
- Inversión total de la operación: $100,000 MXN
- Precio de venta: $135,000 MXN → Utilidad: $35,000 MXN
- Mario aporta $70,000 (70%) → Recibe $70,000 + $24,500 = $94,500
- Elliot aporta $30,000 (30%) → Recibe $30,000 + $10,500 = $40,500

#### 9. Pago__c (Pago)
Registra cada pago recibido del cliente.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| Name | AutoNumber (PAG-{0000}) | Número de pago |
| Cotizacion__c | Lookup | Cotización |
| Fecha__c | Date | Fecha del pago |
| Monto__c | Currency | Monto pagado |
| Metodo_Pago__c | Picklist | Transferencia, Efectivo, Cheque, Otro |
| Notas__c | TextArea | Notas |

---

## Lógica de Negocio (Apex)

### Triggers y Handlers

| Trigger | Handler | Evento | Qué hace |
|---------|---------|--------|----------|
| PartidaCotizacionTrigger | PartidaCotizacionTriggerHandler | After insert/update/delete/undelete | Recalcula Subtotal, IVA, Total y Costo_Total en la Cotización padre |
| PartidaRemisionTrigger | PartidaRemisionTriggerHandler | After insert/update/delete/undelete | Actualiza Cantidad_Entregada en cada partida de cotización y verifica si la entrega está completa |
| AportacionSocioTrigger | AportacionSocioTriggerHandler | After insert/update/delete | Recalcula el porcentaje de inversión y la distribución de utilidad de cada socio |
| PagoTrigger | PagoTriggerHandler | After insert/update/delete/undelete | Recalcula el Monto_Pagado total en la Cotización |
| RemisionTrigger | RemisionTriggerHandler | After update | Cuando una remisión cambia a "Entregada", verifica si todas las partidas están completas |

### Servicios

#### CotizacionService
- `recalcularTotales(Set<Id> cotizacionIds)`: Usa aggregate SOQL para sumar Total_Linea y Costo_Total_Linea de todas las partidas, calcula IVA (16%) y actualiza la Cotización
- `recalcularMontoPagado(Set<Id> cotizacionIds)`: Suma todos los pagos asociados y actualiza Monto_Pagado

#### EntregaService
- `recalcularCantidadesEntregadas(Set<Id> partidaCotizacionIds)`: Suma las cantidades entregadas de todas las remisiones por partida
- `verificarEntregaCompleta(Set<Id> cotizacionIds)`: Verifica si TODAS las partidas de una cotización están completamente entregadas. Si es así, establece `Fecha_Entrega_Completa` = hoy y cambia el estatus a "Entregada"

#### AportacionSocioService
- `recalcularDistribucion(Set<Id> cotizacionIds)`: Calcula el total de inversión, determina el porcentaje de cada socio y distribuye la utilidad proporcionalmente. Usa un guard de recursión (`skipRecalculation`) para evitar loops infinitos

#### OrdenCompraService
- `generarOrdenesCompra(Id cotizacionId)`: Agrupa las partidas por proveedor, filtra solo los que requieren OC, crea una Orden_Compra por proveedor con sus partidas correspondientes

### Schedulable

#### CreditoVencidoSchedulable
Se programa para ejecutarse diariamente. Busca cotizaciones con crédito vencido (`Credito_Vencido__c = true`) y crea una **Tarea** de alta prioridad asignada al dueño de la cotización como recordatorio de cobranza.

### Clase de Utilidades

#### Constants
Centraliza todas las constantes del sistema: tasa de IVA (0.16), valores de estatus, condiciones de pago, etc.

#### TestDataFactory
Clase `@isTest` con métodos helper para crear datos de prueba: Account, Proveedor, Cotización, Partidas, Remisiones, Pagos, Aportaciones.

---

## Componentes LWC

### 1. cotizacionLineItems
**Ubicación:** Record Page de Cotizacion__c
**Función:** Muestra una tabla con todas las partidas de la cotización. Incluye:
- Vista de descripción, proveedor, cantidad, costo, precio, margen %, total por línea y cantidad entregada
- Acciones por fila: Editar y Eliminar
- Resumen inferior: Subtotal, IVA (16%) y Total
- Botón "Nueva Partida" para agregar líneas

### 2. generarOrdenCompra
**Ubicación:** Record Page de Cotizacion__c
**Función:** Muestra una lista de proveedores que requieren OC con el detalle de partidas y totales. Un botón genera las órdenes de compra automáticamente (una por proveedor).

### 3. registrarEntrega
**Ubicación:** Record Page de Cotizacion__c
**Función:** Muestra las remisiones existentes con sus partidas, cantidades entregadas y estado de firma. Permite crear nuevas remisiones con el botón "Nueva Remisión".

### 4. resumenSocios
**Ubicación:** Record Page de Cotizacion__c
**Función:** Tabla con la información de cada socio: inversión, porcentaje de participación, utilidad proyectada y retorno total. Permite agregar nuevas aportaciones.

---

## Flujo Operativo Completo

```
1. COTIZACIÓN
   ├── Crear Account (cliente)
   ├── Crear Cotizacion__c (COT-0001)
   │     ├── Definir: moneda, condición de pago, plazo de entrega
   │     └── Estatus: Borrador
   ├── Agregar Partidas (Partida_Cotizacion__c)
   │     ├── Para cada producto: descripción, cantidad, costo proveedor, precio cliente
   │     ├── El margen % se calcula automáticamente
   │     └── Los totales de la cotización se actualizan automáticamente
   └── Enviar al cliente → Estatus: Enviada

2. ACEPTACIÓN
   ├── Cliente acepta → Estatus: Aceptada
   ├── Registrar aportaciones de socios (Aportacion_Socio__c)
   │     ├── Mario aporta X
   │     ├── Elliot aporta Y
   │     └── % y utilidad se calculan automáticamente
   └── Generar Órdenes de Compra
         ├── Botón "Generar OCs" en el componente LWC
         ├── Se crea una OC por proveedor (solo los que requieren OC)
         └── Cada OC incluye solo las partidas de ese proveedor

3. ENTREGAS
   ├── Crear Remision__c por cada entrega
   │     ├── Agregar Partida_Remision__c (qué cantidad de qué partida)
   │     └── La cantidad entregada se actualiza automáticamente
   ├── Entregas parciales: la fecha de entrega completa NO se establece
   └── Entrega total: cuando TODAS las partidas están completas
         ├── Fecha_Entrega_Completa = hoy
         ├── Estatus → Entregada
         └── Fecha_Vencimiento_Credito = Fecha_Entrega_Completa + Dias_Credito

4. COBRANZA
   ├── Registrar pagos (Pago__c)
   │     ├── Monto_Pagado se actualiza automáticamente
   │     └── Saldo_Pendiente se recalcula
   ├── Si venció el crédito y hay saldo:
   │     └── CreditoVencidoSchedulable crea Tareas de seguimiento diariamente
   └── Pago completo → Estatus: Cobrada

5. REPARTO DE UTILIDAD
   └── Cada socio recibe: su inversión + (utilidad × % de participación)
```

---

## Configuración de la App

### Lightning App: "Intermediario"
Aplicación personalizada con las siguientes pestañas:
- Home
- Cuentas (Account)
- Cotizaciones
- Proveedores
- Órdenes de Compra
- Remisiones
- Pagos
- Reportes
- Dashboards

### Permission Set: "Intermediario Admin"
Otorga acceso completo (CRUD + View All + Modify All) a los 9 objetos custom, visibilidad de todas las tabs, acceso a la app y permisos de campo para todos los campos custom.

---

## Tests Unitarios

| Clase de Test | Cobertura |
|---------------|-----------|
| CotizacionServiceTest | Cálculo de totales con múltiples partidas, eliminación de partidas, cotización vacía |
| PartidaCotizacionTriggerTest | Inserción y actualización de partidas recalculan totales |
| EntregaServiceTest | Entrega parcial, entrega completa, entregas múltiples partidas |
| AportacionSocioServiceTest | Distribución 70/30, socio único al 100% |
| OrdenCompraServiceTest | Generación de OCs (2 proveedores con OC, 1 sin OC), sin partidas |
| PagoTriggerTest | Inserción y eliminación de pagos recalculan monto pagado |
| PartidaRemisionTriggerTest | Inserción y eliminación de entregas recalculan cantidades |
| CreditoVencidoSchedulableTest | Ejecución del schedulable crea tareas de cobranza |

---

## Estructura de Archivos

```
force-app/main/default/
├── applications/
│   └── Intermediario.app-meta.xml
├── classes/
│   ├── Constants.cls
│   ├── CotizacionService.cls
│   ├── EntregaService.cls
│   ├── AportacionSocioService.cls
│   ├── OrdenCompraService.cls
│   ├── CotizacionController.cls
│   ├── OrdenCompraController.cls
│   ├── PartidaCotizacionTriggerHandler.cls
│   ├── PartidaRemisionTriggerHandler.cls
│   ├── AportacionSocioTriggerHandler.cls
│   ├── PagoTriggerHandler.cls
│   ├── RemisionTriggerHandler.cls
│   ├── CreditoVencidoSchedulable.cls
│   ├── TestDataFactory.cls
│   ├── CotizacionServiceTest.cls
│   ├── EntregaServiceTest.cls
│   ├── AportacionSocioServiceTest.cls
│   ├── OrdenCompraServiceTest.cls
│   ├── PagoTriggerTest.cls
│   ├── PartidaCotizacionTriggerTest.cls
│   ├── PartidaRemisionTriggerTest.cls
│   ├── CreditoVencidoSchedulableTest.cls
│   └── (+ 22 archivos .cls-meta.xml)
├── triggers/
│   ├── PartidaCotizacionTrigger.trigger
│   ├── PartidaRemisionTrigger.trigger
│   ├── AportacionSocioTrigger.trigger
│   ├── PagoTrigger.trigger
│   ├── RemisionTrigger.trigger
│   └── (+ 5 archivos .trigger-meta.xml)
├── lwc/
│   ├── cotizacionLineItems/
│   ├── generarOrdenCompra/
│   ├── registrarEntrega/
│   └── resumenSocios/
├── objects/
│   ├── Proveedor__c/          (objeto + 7 campos)
│   ├── Cotizacion__c/         (objeto + 21 campos + 2 validation rules)
│   ├── Partida_Cotizacion__c/ (objeto + 14 campos + 2 validation rules)
│   ├── Orden_Compra__c/       (objeto + 6 campos)
│   ├── Partida_Orden_Compra__c/ (objeto + 7 campos)
│   ├── Remision__c/           (objeto + 5 campos)
│   ├── Partida_Remision__c/   (objeto + 3 campos)
│   ├── Aportacion_Socio__c/   (objeto + 6 campos + 1 validation rule)
│   └── Pago__c/               (objeto + 5 campos)
├── tabs/                      (5 tabs)
├── permissionsets/             (Intermediario_Admin)
└── layouts/                   (vacío - Salesforce genera defaults)
```

**Total: 161 archivos de metadata**

---

## Despliegue

### 1. Crear Scratch Org
```bash
sf org create scratch -f config/project-scratch-def.json -a intermediario -d 30
```

### 2. Desplegar el código
```bash
sf project deploy start -o intermediario
```

### 3. Asignar Permission Set
```bash
sf org assign permset -n Intermediario_Admin -o intermediario
```

### 4. Ejecutar Tests
```bash
sf apex run test -o intermediario --code-coverage --result-format human
```

### 5. Programar el Schedulable de Crédito Vencido
```bash
sf apex run -o intermediario -f scripts/apex/schedule_credito.apex
```

Contenido del script:
```apex
CreditoVencidoSchedulable job = new CreditoVencidoSchedulable();
String cronExp = '0 0 8 * * ?'; // Diario a las 8 AM
System.schedule('Alerta Credito Vencido', cronExp, job);
```

### 6. Abrir la Org
```bash
sf org open -o intermediario
```

---

## Decisiones de Diseño

### ¿Por qué no usar el objeto Quote estándar?
El Quote estándar de Salesforce está acoplado a Opportunity y Product/PriceBook. Este negocio no tiene catálogo fijo ni oportunidades en el sentido tradicional. Un objeto custom da total flexibilidad.

### ¿Por qué Apex triggers en vez de Flows para roll-ups?
Los roll-ups requieren aggregate SOQL sobre relaciones Lookup (no Master-Detail). Los Flows pueden hacer esto pero con menor rendimiento en operaciones bulk. Los triggers con aggregate queries son más eficientes y se comportan correctamente con Data Loader.

### ¿Por qué Master-Detail para Partida_Cotizacion → Cotizacion?
Las partidas nunca existen sin cotización. Master-Detail garantiza cascade delete y abre la puerta a usar Roll-Up Summary Fields nativos en el futuro.

### ¿Por qué campos almacenados (no fórmulas) para Subtotal, Total, Monto_Pagado?
Las fórmulas de Salesforce no pueden agregar registros hijos. Estos valores se calculan desde los registros hijos mediante triggers y se almacenan para consultas eficientes y reportes.

### ¿Por qué un guard de recursión en AportacionSocioTriggerHandler?
Cuando el trigger actualiza los registros de Aportacion_Socio (para establecer porcentaje y utilidad), se dispararía nuevamente el trigger after update. Un flag estático `skipRecalculation` previene el loop infinito.

---

## Vacíos No Implementados (Por Diseño)

Siguiendo la instrucción del negocio de **no inventar políticas no definidas**, los siguientes puntos NO están automatizados:

- **Política formal de margen**: El margen es libre por partida
- **Aprobación de crédito**: No hay workflow de aprobación, se negocia por operación
- **Proceso de cobranza vencida**: Solo se crean tareas recordatorio, sin escalación formal
- **Cancelaciones post-aceptación**: Se puede cambiar el estatus manualmente
- **Devoluciones y garantías**: No existe proceso formal
- **Regla de tipo de cambio**: Se captura manualmente
- **Facturación**: No incluida en el flujo actual
- **Generación de PDFs**: Marcado como fase futura (Visualforce o LWC)
