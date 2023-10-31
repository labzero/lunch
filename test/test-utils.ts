import type { VNode } from "preact";
import { render, RenderOptions } from "@testing-library/react";

const AllTheProviders = ({ children }: { children: VNode }) => children;

const customRender = (ui: VNode, options?: Omit<RenderOptions, "wrapper">) =>
  render(ui, { wrapper: AllTheProviders, ...options });

export * from "@testing-library/react";
export { customRender as render };
