package Carrier.CarriOn.Chat;

import Carrier.CarriOn.User.UserEntity;
import Carrier.CarriOn.User.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class ChatRoomService {

    @Autowired
    private ChatRoomRepository chatRoomRepository;

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public List<ChatRoom> findChatRoomsByUserId(Long userId) {
        List<ChatRoom> chatRooms = chatRoomRepository.findByUserId(userId);
        for (ChatRoom chatRoom : chatRooms) {
            chatRoom.getParticipants().size(); // 컬렉션 초기화
        }
        return chatRooms;
    }
}
