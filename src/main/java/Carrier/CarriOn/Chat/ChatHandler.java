package Carrier.CarriOn.Chat;

import Carrier.CarriOn.User.UserEntity;
import Carrier.CarriOn.User.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.web.socket.*;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

public class ChatHandler extends TextWebSocketHandler {
    private final ObjectMapper objectMapper;
    private final ChatService chatService;

    private final UserRepository userRepository;
    private final Map<Long, WebSocketSession> userSessions = new ConcurrentHashMap<>();

    public ChatHandler(ObjectMapper objectMapper, ChatService chatService, UserRepository userRepository) {
        this.objectMapper = objectMapper;
        this.chatService = chatService;
        this.userRepository = userRepository;
    }

    //웹소켓 연결 후 user id 저장
    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String userIdStr = session.getUri().getPath().split("/")[2];
        Long userId = Long.valueOf(userIdStr);
        userSessions.put(userId, session);
    }

    // 웹소켓 연결 종료 후 user id 제거
    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        String userIdStr = session.getUri().getPath().split("/")[2];
        Long userId = Long.valueOf(userIdStr);
        userSessions.remove(userId);
    }

    // message 관리
    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        String payload = message.getPayload();
        ChatMessageRequest chatMessageRequest = objectMapper.readValue(payload, ChatMessageRequest.class);

        Long senderId = chatMessageRequest.getSenderId();
        Long chatRoomId = chatMessageRequest.getChatRoomId();
        String messageText = chatMessageRequest.getMessage();

        // Null 체크 및 디버깅 로그 추가
        if (senderId == null || chatRoomId == null) {
            throw new IllegalArgumentException("Sender ID and Chat Room ID must not be null");
        }

        // 디버깅을 위한 로그 추가
        System.out.println("Sender ID: " + senderId);
        System.out.println("Chat Room ID: " + chatRoomId);

        ChatRoom chatRoom = chatService.findChatRoomById(chatRoomId, senderId);

        ChatMessage chatMessage = new ChatMessage();
        chatMessage.setSenderId(senderId);
        chatMessage.setMessage(messageText);
        chatMessage.setTimestamp(LocalDateTime.now());
        chatMessage.setChatRoom(chatRoom);
        chatService.saveMessage(chatMessage);

        List<String> participantNames = chatRoom.getParticipants().stream()
                .map(UserEntity::getName)
                .collect(Collectors.toList());

        for (UserEntity member : chatRoom.getParticipants()) {
            if (!member.getId().equals(senderId)) { // 발신자 제외
                WebSocketSession memberSession = userSessions.get(member.getId());
                if (memberSession != null && memberSession.isOpen()) {
                    ChatMessageDTO chatMessageDTO = new ChatMessageDTO(
                            chatMessage.getId(),
                            chatRoomId, // chatRoomId 추가
                            chatRoom.getName(),
                            chatMessage.getSenderId(),
                            chatService.getUserNameById(chatMessage.getSenderId()),
                            chatMessage.getMessage(),
                            chatMessage.getTimestamp().toString(),
                            chatService.getProfileImageBase64(userRepository.findById(chatMessage.getSenderId()).orElseThrow(() -> new RuntimeException("User not found"))),
                            participantNames // participantNames 추가
                    );
                    memberSession.sendMessage(new TextMessage(objectMapper.writeValueAsString(chatMessageDTO)));
                }
            }
        }
    }
}
