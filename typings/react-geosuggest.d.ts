import "@ubilabs/react-geosuggest";

declare module "@ubilabs/react-geosuggest" {
  export interface Suggest {
    description: string;
    place_id: string;
    terms: { value: string }[];
  }
  export default interface Geosuggest {
    showSuggests: () => void;
  }
}
