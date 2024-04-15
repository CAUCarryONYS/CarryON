package Carrier.CarriOn;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class ChatRoomController {
    @Autowired
    private ChatRoomRepository chatRoomRepository;

    // 채팅방 생성
    @PostMapping("/chatrooms")
    public ChatRoomEntity createChatRoom(@RequestBody ChatRoomEntity chatRoom) {
        return chatRoomRepository.save(chatRoom);
    }

    // 채팅방 목록 조회
    @GetMapping("/chatrooms")
    public List<ChatRoomEntity> getAllChatRooms() {
        return chatRoomRepository.findAll();
    }
}
