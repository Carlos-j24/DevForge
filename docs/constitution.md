# Constitución — DevForge

Principios innegociables. Toda spec, plan y tarea debe cumplirlos.

1. **Diagnosticar no es modificar**: un check nunca instala, cambia ni borra nada. Cualquier acción de reparación será explícita, opcional y pedirá confirmación.
2. **La spec manda**: nada se implementa si no está en la spec activa (`specs/NNN-*/`). Si falta una decisión, se para y se pregunta.
3. **Lógica separada de presentación**: los checks devuelven objetos `ToolCheck`; solo el orquestador imprime en consola o genera JSON.
4. **Tests como puerta**: la lógica se prueba con Pester (5.5 o superior). Prohibido avanzar con tests en rojo.
5. **Contratos estables**: el esquema JSON y los códigos de salida (0/1/2) solo cambian con una nueva versión mayor y una entrada en el CHANGELOG.
6. **Idioma**: código en inglés; mensajes al usuario, documentación y commits en español.
7. **La IA ayuda, la persona decide**: ningún agente aprueba sus propias specs ni hace push sin revisión humana.
