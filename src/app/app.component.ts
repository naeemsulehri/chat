import { Endpoints } from './../helpers/endpoints';
import { Component, NgZone } from '@angular/core';
import { Message, MessageStatus } from '../models/Message';
import { ChatService } from '../services/chat.service';
import { HttpClient } from '@angular/common/http';
import{FormBuilder, FormGroup, ControlContainer} from '@angular/forms';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {

  constructor(private http: HttpClient, private formBuilder: FormBuilder,
    private chatService: ChatService, private _ngZone: NgZone) { 
      this.subscribeToEvents();
      this.subscribeToRead();
    }

uploadForm: FormGroup;
txtMessage: string = '';
file: any = null;
uniqueID: string = new Date().getTime().toString();
messages = new Array<Message>();
message = new Message();

ngOnInit(){

  this.uploadForm = this.formBuilder.group({
    profile:[''],
    textMessage:['']
    // userName:[''],
    // userId:['']
    
  });
}
  OnFileSelect(event){
    this.file = event.target.files[0];
    console.log(this.file);
  }
  onSubmit(){
    var date = new Date().getUTCDate().toString();

    if(this.file !== null || this.file != 'undefined'){
      const formData = new FormData();
      formData.append(date, this.uploadForm.get('profile').value)
      this.http.post<any>(Endpoints.UPLOAD_IMAGE_API, formData).subscribe(
        (res)=> console.log(res),
        (err)=> console.log(err)
      );
    }

    if (this.txtMessage) {
      this.message = new Message();
      this.message.clientuniqueid = this.uniqueID;
      this.message.status = MessageStatus.Sent;
      this.message.message = this.txtMessage;
      this.message.date = new Date();

      this.messages.push(this.message);
      this.chatService.sendMessage(this.message);
      this.txtMessage = '';
    }    
  }
  private subscribeToEvents(): void {

    this.chatService.messageReceived.subscribe((message: Message) => {
      this._ngZone.run(() => {
        if (message.clientuniqueid !== this.uniqueID) {
          this.message.status = MessageStatus.Delivered;
           this.messages.push(message); 
        }
      });
    });
  }

  private subscribeToRead(): void {

    this.chatService.messageReceived.subscribe((message: Message) => {
      this._ngZone.run(() => {
        if (message.clientuniqueid !== this.uniqueID) {
          this.message.status = MessageStatus.Read;
           this.messages.push(message); 
        }
      });
    });
  }
}


//   [x: string]: any;
  

  // title = 'ClientApp';
  // txtMessage: string = '';

//   uniqueID: string = new Date().getTime().toString();
//   messages = new Array<Message>();
//   message = new Message();
//   constructor(
//     private  chatService: ChatService,
//     private http: HttpClient,
//     private _ngZone: NgZone
//   ) {
//     this.subscribeToEvents();
//   }
//   sendMessage(file: any): void {
    
//     if(file){
//       this.message.files.push(file);
//     }

//     if (this.txtMessage) {
//       this.message = new Message();
//       this.message.clientuniqueid = this.uniqueID;
//       this.message.type = "sent";
//       this.message.message = this.txtMessage;
//       this.message.date = new Date();

//       this.messages.push(this.message);
//       this.chatService.sendMessage(this.message);
//       this.txtMessage = '';
//     }
//   }
//   private subscribeToEvents(): void {

//     this.chatService.messageReceived.subscribe((message: Message) => {
//       this._ngZone.run(() => {
//         if (message.clientuniqueid !== this.uniqueID) {
//           message.type = "received";
//           this.message.isRead= true;
//            this.messages.push(message);
//         }
//       });
//     });
//   }


// // ............
// fileData: File = null;

 
// fileProgress(fileInput: any) {
//   this.fileData = <File>fileInput.target.files[0];
// }

// onSubmit() {
//   const formData = new FormData();
//   formData.append('file', this.fileData);
//   this.http.post('url/to/your/api', formData)
//     .subscribe(res => {
//       console.log(res);
//       alert('SUCCESS !!');
//     });
//     this.fileStatus = CheckFileStatus.is_filel;
// }

  
// }

