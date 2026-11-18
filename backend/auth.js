const jwt = require('jsonwebtoken');
require('dotenv').config();

// Verifica que la petición traiga un token JWT válido en el
// encabezado Authorization, con el formato "Bearer <token>".
function verificarToken(req, res, next) {
    const encabezado = req.headers['authorization'];

    if (!encabezado || !encabezado.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Token no proporcionado' });
    }

    const token = encabezado.split(' ')[1];

    try {
        const datos = jwt.verify(token, process.env.JWT_SECRET);
        req.usuario = datos; // queda disponible en las rutas siguientes
        next();
    } catch (error) {
        return res.status(401).json({ error: 'Token inválido o expirado' });
    }
}

// Genera un middleware que además exige uno de los roles indicados.
// Se usa así: verificarRol('ADMINISTRADOR', 'ELECTRICISTA')
function verificarRol(...rolesPermitidos) {
    return (req, res, next) => {
        if (!rolesPermitidos.includes(req.usuario.rol)) {
            return res.status(403).json({ error: 'No tienes permiso para esta acción' });
        }
        next();
    };
}

module.exports = { verificarToken, verificarRol };