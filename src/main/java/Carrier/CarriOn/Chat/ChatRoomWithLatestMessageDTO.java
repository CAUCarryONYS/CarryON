package Carrier.CarriOn.Chat;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class ChatRoomWithLatestMessageDTO {
    private Long chatRoomId;
    private String chatRoomName; // chatRoomName 추가
    private List<Long> participantIds;
    private List<String> participantNames;
    private List<String> participantProfileImages;
    private String latestMessage;
    private Long latestMessageSenderId;
    private String latestMessageSenderName;
    private String latestMessageTimestamp;

    // Constructor
    public ChatRoomWithLatestMessageDTO(Long chatRoomId, String chatRoomName, List<Long> participantIds, List<String> participantNames, List<String> participantProfileImages, String latestMessage, Long latestMessageSenderId, String latestMessageSenderName, String latestMessageTimestamp) {
        this.chatRoomId = chatRoomId;
        this.chatRoomName = chatRoomName; // chatRoomName 추가
        this.participantIds = participantIds;
        this.participantNames = participantNames;
        this.participantProfileImages = participantProfileImages;
        this.latestMessage = latestMessage;
        this.latestMessageSenderId = latestMessageSenderId;
        this.latestMessageSenderName = latestMessageSenderName;
        this.latestMessageTimestamp = latestMessageTimestamp;
    }

    public String getLatestMessageTimestamp() {
        return latestMessageTimestamp;
    }

}
