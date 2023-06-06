import { Decision } from "../../../interfaces";

export interface NotificationContentProps {
  decision?: Decision;
  loggedIn: boolean;
  newName?: string;
  showMapAndInfoWindow: () => void;
  restaurantName?: string;
  tagName?: string;
  user?: string;
}
