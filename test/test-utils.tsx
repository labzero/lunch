import { ReactElement } from 'react';
import { render, RenderOptions } from '@testing-library/react';

const AllTheProviders = ({ children }: {children: ReactElement}) => children;

const customRender = (
  ui: ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>,
) => render(ui, { wrapper: AllTheProviders, ...options });

export * from '@testing-library/react';
export { customRender as render };
