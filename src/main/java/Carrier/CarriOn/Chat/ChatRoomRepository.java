package Carrier.CarriOn.Chat;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Set;

public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {

    @Query("SELECT CASE WHEN COUNT(cr) > 0 THEN true ELSE false END " +
            "FROM ChatRoom cr JOIN cr.participants p " +
            "WHERE p.id IN :participantIds " +
            "GROUP BY cr.id " +
            "HAVING COUNT(DISTINCT p.id) = :size")
    Boolean existsByParticipantsIds(@Param("participantIds") Set<Long> participantIds, @Param("size") long size);

    @Query("SELECT cr FROM ChatRoom cr JOIN cr.participants p WHERE p.id = :userId")
    List<ChatRoom> findByUserId(@Param("userId") Long userId);
}
