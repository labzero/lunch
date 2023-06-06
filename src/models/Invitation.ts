import { Column, DataType, Model, Table } from "sequelize-typescript";

@Table({ modelName: "invitation" })
class Invitation extends Model {
  @Column({ allowNull: false, type: DataType.CITEXT, unique: true })
  email: string;

  @Column
  confirmedAt: Date;

  @Column({ unique: true })
  confirmationToken: string;

  @Column
  confirmationSentAt: Date;
}

export default Invitation;
