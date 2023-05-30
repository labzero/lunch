interface SequelizeMockObject {
  create: () => void;
  destroy: () => void;
  findAll: () => Promise<any[]>;
  findAllForUser: (userId: string) => Promise<any[]>;
  findOne: () => Promise<any>;
  hasMany: (obj: SequelizeMockObject) => void;
  scope: () => void;
}

declare class SequelizeMock {
  define(modelName: string, schema: any) {
    return new SequelizeMockObject();
  }
}

declare module "sequelize-mock" {
  export default SequelizeMock;
}
