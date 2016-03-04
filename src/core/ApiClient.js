class ApiClient {
  constructor(response) {
    this.response = response;
  }

  processResponse() {
    return this.response.json().then(json => {
      if (this.response.status >= 400) {
        throw new Error(json.data.message);
      }
      return json.data;
    });
  }
}

export default ApiClient;
