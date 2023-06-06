import { ButtonProps } from "react-bootstrap/Button";

declare module "react-bootstrap/Button" {
  export interface ButtonPropsWithXsSize extends ButtonProps {
    size?: "sm" | "lg" | "xs";
  }
}
