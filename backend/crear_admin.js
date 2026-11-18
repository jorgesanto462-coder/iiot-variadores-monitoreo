require('dotenv').config();
const bcrypt = require('bcrypt');
const pool = require('./db');

async function crearAdmin() {
    const nombreUsuario = 'admin';
    const passwordPlano = 'Admin.SintenIOT';

    const hash = await bcrypt.hash(passwordPlano, 10);

    const [roles] = await pool.query(
        "SELECT id_rol FROM roles WHERE nombre_rol = 'ADMINISTRADOR'"
    );
    const idRol = roles[0].id_rol;

    await pool.query(
        'INSERT INTO usuarios (nombre_usuario, password_hash, id_rol) VALUES (?, ?, ?)',
        [nombreUsuario, hash, idRol]
    );

    console.log(`Usuario "${nombreUsuario}" creado con contraseña: ${passwordPlano}`);
    process.exit(0);
}

crearAdmin().catch((error) => {
    console.error('Error al crear el usuario:', error.message);
    process.exit(1);
});