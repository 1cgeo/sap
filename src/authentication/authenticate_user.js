"use strict";

const axios = require("axios");

const {
  AppError,
  http_code,
  config: { AUTH_SERVER }
} = require("../utils");

const authorization = async (usuario, senha) => {
  const server = AUTH_SERVER.endsWith("/")
    ? `${AUTH_SERVER}login`
    : `${AUTH_SERVER}/login`;
  try {
    const response = await axios.post(server, {
      usuario,
      senha
    });

    if (!response || response.status !== 201 || !("data" in response)) {
      throw new Error();
    }

    return response.data.success || false;
  } catch (e) {
    throw new AppError(
      "Erro ao se comunicar com o servidor de autenticação",
      http_code.InternalError
    );
  }
};

module.exports = authorization;
