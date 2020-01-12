export class Message {
    clientuniqueid: string;
    message: string;
    date: Date;
    status: MessageStatus;
  }

export enum MessageStatus{
  Sent,
  Delivered,
  Read
}
