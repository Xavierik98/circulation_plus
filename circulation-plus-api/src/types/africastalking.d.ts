// Le paquet africastalking ne fournit pas de types.
declare module 'africastalking' {
  interface SmsApi {
    send(opts: Record<string, unknown>): Promise<unknown>;
  }
  interface AfricasTalkingClient {
    SMS: SmsApi;
  }
  function AfricasTalking(credentials: {
    apiKey: string;
    username: string;
  }): AfricasTalkingClient;
  export default AfricasTalking;
}
