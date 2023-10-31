import { Column, DataType, Model, Table } from "sequelize-typescript";

@Table({ modelName: "invitation" })
class Invitation extends Model {
  @Column({ allowNull: false, type: DataType.CITEXT, unique: true })
  email: string;

  @Column(DataType.DATE)
  confirmedAt: Date;

  @Column({ type: DataType.STRING, unique: true })
  confirmationToken: string;

  @Column(DataType.DATE)
  confirmationSentAt: Date;
}

export default Invitation;
