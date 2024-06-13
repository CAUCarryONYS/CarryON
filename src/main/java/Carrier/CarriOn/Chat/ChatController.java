package Carrier.CarriOn.Chat;

import jakarta.servlet.http.HttpSession;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Set;

@RestController
@RequestMapping("/chat")
@CrossOrigin(origins = "http://localhost:8085")
public class ChatController {
    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    // 해당 채팅방 메시지 반환 / sender, message, timestamp
    @GetMapping("/messages/{chatRoomId}")
    public ResponseEntity<List<ChatMessageDTO>> getChatMessages(@PathVariable Long chatRoomId, HttpSession session) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.badRequest().body(null);
        }

        List<ChatMessageDTO> messageDTOs = chatService.getChatMessages(chatRoomId, userId);
        return ResponseEntity.ok(messageDTOs);
    }

    // 채팅방 생성 (개인 및 그룹 가능 / 참여자 : 2 ~ more)
    @PostMapping("/createChatRoom")
    public ResponseEntity<String> createChatRoom(@RequestBody CreateChatRoomRequest request, HttpSession session) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.badRequest().body("로그인이 필요합니다.");
        }

        chatService.createChatRoom(request.getName(), request.getMemberIds());
        return ResponseEntity.ok("채팅방 생성 성공");
    }

    // 로그인 사용자의 채팅방 목록
    @GetMapping("/chatRooms")
    public ResponseEntity<List<ChatRoomWithLatestMessageDTO>> getChatRoomsWithLatestMessages(HttpSession session) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.badRequest().body(null);
        }

        List<ChatRoomWithLatestMessageDTO> chatRoomsWithLatestMessages = chatService.getChatRoomsWithLatestMessages(userId);
        return ResponseEntity.ok(chatRoomsWithLatestMessages);
    }
}
