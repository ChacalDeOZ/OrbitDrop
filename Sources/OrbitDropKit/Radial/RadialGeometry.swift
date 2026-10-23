import Foundation
import CoreGraphics

public enum RadialGeometry: Sendable {
    /// Retorna ângulo em graus (0° a 360°), no sentido horário partindo do topo (12 horas).
    /// Em AppKit, y cresce para cima, logo o vetor do topo é (0, dy > 0).
    public static func angle(from center: CGPoint, to point: CGPoint) -> CGFloat {
        let dx = point.x - center.x
        let dy = point.y - center.y

        let radians = atan2(dx, dy)
        var degrees = radians * 180.0 / .pi
        if degrees < 0 {
            degrees += 360.0
        }
        if degrees >= 360.0 {
            degrees -= 360.0
        }
        return degrees
    }

    /// Retorna a distância euclidiana entre dois pontos.
    public static func distance(from center: CGPoint, to point: CGPoint) -> CGFloat {
        let dx = point.x - center.x
        let dy = point.y - center.y
        return hypot(dx, dy)
    }

    /// Identifica o índice do setor ativo, rejeitando toques dentro do raio interno ou fora do raio externo.
    public static func sectorIndex(
        at point: CGPoint,
        center: CGPoint,
        sectorCount: Int,
        innerRadius: CGFloat,
        outerRadius: CGFloat
    ) -> Int? {
        guard sectorCount > 0 else { return nil }

        let dist = distance(from: center, to: point)
        guard dist >= innerRadius && dist <= outerRadius else {
            return nil
        }

        let ang = angle(from: center, to: point)
        let sectorSpan = 360.0 / CGFloat(sectorCount)

        // Centraliza o setor 0 em 0° (topo):
        var shifted = ang + (sectorSpan / 2.0)
        if shifted >= 360.0 {
            shifted -= 360.0
        }

        let index = Int(shifted / sectorSpan)
        return min(max(index, 0), sectorCount - 1)
    }

    /// Restringe o centro da roda às bordas visíveis de um quadro de tela qualquer (inclusive multi-monitor).
    public static func clampedCenter(
        cursor: CGPoint,
        screenFrame: CGRect,
        wheelRadius: CGFloat,
        margin: CGFloat = 16.0
    ) -> CGPoint {
        let minX = screenFrame.minX + margin + wheelRadius
        let maxX = max(minX, screenFrame.maxX - (margin + wheelRadius))
        let minY = screenFrame.minY + margin + wheelRadius
        let maxY = max(minY, screenFrame.maxY - (margin + wheelRadius))

        let clampedX = min(max(cursor.x, minX), maxX)
        let clampedY = min(max(cursor.y, minY), maxY)

        return CGPoint(x: clampedX, y: clampedY)
    }

    /// Restringe o centro da roda quando apenas o tamanho da tela principal for conhecido.
    public static func clampedCenter(
        cursor: CGPoint,
        screenSize: CGSize,
        wheelRadius: CGFloat,
        margin: CGFloat = 16.0
    ) -> CGPoint {
        let frame = CGRect(origin: .zero, size: screenSize)
        return clampedCenter(cursor: cursor, screenFrame: frame, wheelRadius: wheelRadius, margin: margin)
    }

    /// Calcula o ponto médio (em coordenadas cartesianas) de um setor radial a um dado raio.
    public static func sectorMidPoint(
        sectorIndex: Int,
        sectorCount: Int,
        center: CGPoint,
        radius: CGFloat
    ) -> CGPoint {
        guard sectorCount > 0 else { return center }
        let sectorSpan = 360.0 / CGFloat(sectorCount)
        let midAngleDegrees = CGFloat(sectorIndex) * sectorSpan
        let rad = midAngleDegrees * .pi / 180.0

        let dx = radius * sin(rad)
        let dy = radius * cos(rad)
        return CGPoint(x: center.x + dx, y: center.y + dy)
    }
}
