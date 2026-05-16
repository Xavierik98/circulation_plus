// Erreur métier typée : porte un statut HTTP et un code d'erreur stable
// exposé au client dans l'enveloppe { success: false, error, code }.
export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: string;

  constructor(statusCode: number, code: string, message: string) {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.code = code;
    Object.setPrototypeOf(this, AppError.prototype);
  }

  static badRequest(message: string, code = 'BAD_REQUEST'): AppError {
    return new AppError(400, code, message);
  }

  static unauthorized(message: string, code = 'UNAUTHORIZED'): AppError {
    return new AppError(401, code, message);
  }

  static forbidden(message: string, code = 'FORBIDDEN'): AppError {
    return new AppError(403, code, message);
  }

  static notFound(message: string, code = 'NOT_FOUND'): AppError {
    return new AppError(404, code, message);
  }

  static conflict(message: string, code = 'CONFLICT'): AppError {
    return new AppError(409, code, message);
  }

  static tooManyRequests(message: string, code = 'RATE_LIMITED'): AppError {
    return new AppError(429, code, message);
  }

  static internal(message: string, code = 'INTERNAL_ERROR'): AppError {
    return new AppError(500, code, message);
  }
}
