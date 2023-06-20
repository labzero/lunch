import { Reducer } from "../interfaces";

const flashes: Reducer<"flashes"> = (state, action) => {
  switch (action.type) {
    case "FLASH_ERROR": {
      return [
        ...state,
        {
          id: action.id,
          message: action.message,
          type: "error",
        },
      ];
    }
    case "FLASH_SUCCESS": {
      return [
        ...state,
        {
          id: action.id,
          message: action.message,
          type: "success",
        },
      ];
    }
    case "EXPIRE_FLASH": {
      return state.filter((arr) => arr.id !== action.id);
    }
    default:
      break;
  }
  return state;
};

export default flashes;
